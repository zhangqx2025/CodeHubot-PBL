"""
数据导出工具
支持导出为 CSV 和 Excel 格式
"""
import csv
import io
from typing import List, Dict, Any
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive


def export_to_csv(data: List[Dict[str, Any]], headers: List[str]) -> str:
    """
    导出数据到 CSV 格式
    
    Args:
        data: 数据列表
        headers: 列标题列表
    
    Returns:
        CSV 字符串
    """
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=headers)
    
    # 写入标题
    writer.writeheader()
    
    # 写入数据
    for row in data:
        writer.writerow(row)
    
    csv_content = output.getvalue()
    output.close()
    
    return csv_content


def export_progress_to_csv(progress_data: List[Dict[str, Any]]) -> str:
    """
    导出学习进度数据到 CSV
    
    Args:
        progress_data: 学习进度数据列表
    
    Returns:
        CSV 字符串
    """
    headers = [
        '学生姓名',
        '学号',
        '完成率(%)',
        '状态',
        '已完成单元',
        '总单元数',
        '学习时长(小时)',
        '提交作业数',
        '最后活跃时间'
    ]
    
    # 转换数据格式
    csv_data = []
    for item in progress_data:
        csv_data.append({
            '学生姓名': item.get('name', ''),
            '学号': item.get('student_number', ''),
            '完成率(%)': item.get('completion_rate', 0),
            '状态': get_status_name(item.get('status', '')),
            '已完成单元': item.get('completed_units', 0),
            '总单元数': item.get('total_units', 0),
            '学习时长(小时)': item.get('learning_hours', 0),
            '提交作业数': item.get('submissions_count', 0),
            '最后活跃时间': item.get('last_active', '')
        })
    
    return export_to_csv(csv_data, headers)


def export_homework_to_csv(homework_data: List[Dict[str, Any]]) -> str:
    """
    导出作业数据到 CSV
    
    Args:
        homework_data: 作业数据列表
    
    Returns:
        CSV 字符串
    """
    headers = [
        '作业标题',
        '所属单元',
        '状态',
        '是否必做',
        '提交人数',
        '总人数',
        '待批改数',
        '开始时间',
        '截止时间',
        '创建时间'
    ]
    
    # 转换数据格式
    csv_data = []
    for item in homework_data:
        csv_data.append({
            '作业标题': item.get('title', ''),
            '所属单元': item.get('unit_name', ''),
            '状态': get_homework_status_name(item.get('status', '')),
            '是否必做': '是' if item.get('is_required', False) else '否',
            '提交人数': item.get('submitted_count', 0),
            '总人数': item.get('total_count', 0),
            '待批改数': item.get('to_review_count', 0),
            '开始时间': item.get('start_time', ''),
            '截止时间': item.get('deadline', ''),
            '创建时间': item.get('created_at', '')
        })
    
    return export_to_csv(csv_data, headers)


def export_submissions_to_csv(submissions_data: List[Dict[str, Any]]) -> str:
    """
    导出作业提交数据到 CSV
    
    Args:
        submissions_data: 作业提交数据列表
    
    Returns:
        CSV 字符串
    """
    headers = [
        '学生姓名',
        '学号',
        '状态',
        '分数',
        '反馈',
        '评阅人',
        '评阅时间',
        '提交时间'
    ]
    
    # 转换数据格式
    csv_data = []
    for item in submissions_data:
        csv_data.append({
            '学生姓名': item.get('student_name', ''),
            '学号': item.get('student_number', ''),
            '状态': get_submission_status_name(item.get('status', '')),
            '分数': item.get('score', '') or '未评分',
            '反馈': item.get('feedback', '') or '',
            '评阅人': item.get('grader_name', '') or '',
            '评阅时间': item.get('graded_at', '') or '',
            '提交时间': item.get('submitted_at', '') or '未提交'
        })
    
    return export_to_csv(csv_data, headers)


def get_status_name(status: str) -> str:
    """获取状态名称"""
    status_map = {
        'not_started': '未开始',
        'in_progress': '进行中',
        'completed': '已完成'
    }
    return status_map.get(status, status)


def get_homework_status_name(status: str) -> str:
    """获取作业状态名称"""
    status_map = {
        'draft': '未发布',
        'ongoing': '进行中',
        'ended': '已截止'
    }
    return status_map.get(status, status)


def get_submission_status_name(status: str) -> str:
    """获取提交状态名称"""
    status_map = {
        'pending': '待提交',
        'in-progress': '进行中',
        'blocked': '受阻',
        'review': '待批改',
        'completed': '已完成'
    }
    return status_map.get(status, status)


def generate_export_filename(prefix: str, extension: str = 'csv') -> str:
    """
    生成导出文件名
    
    Args:
        prefix: 文件名前缀
        extension: 文件扩展名
    
    Returns:
        文件名
    """
    timestamp = get_beijing_time_naive().strftime('%Y%m%d_%H%M%S')
    return f"{prefix}_{timestamp}.{extension}"
